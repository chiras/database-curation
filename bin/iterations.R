library(ggplot2)

Species.data <- read.table("tmp.cut", sep = "|", fill = T, header = F)
colnames(Species.data) <- c("ID", "Acc1", "Genus1", "Species1", "Acc2", "Genus2", "Species2")

Species.list <- names(table(c(Species.data$Species1, Species.data$Species2)))

Results.all <- data.frame(med.dist = c(),species=c())
Results.all.dir <- data.frame(med.dist = c(),species=c())

thres_iter = c(50, 75, 80, 85, 90, 92.5, 95, 97)

results_dyn = data.frame(threshold=c(), type=c(), perc=c(), species=c())

input_dyn <- list() #input_org is your original table
iteration <- as.character(0)
input_dyn[[iteration]] <- Species.data
total_badones <- c()

swit <- "inc"
for (iter in 1:length(thres_iter)){
  print(paste("Iter: ",iter) )
  if(swit == "dir") {
    Species.data.x <- Species.data
  }else{
    Species.data.x <- input_dyn[[iteration]]
  }

  iterationp <- iteration
  iteration <- as.character(thres_iter[iter])
  Results.all <- data.frame(med.dist = c(),species=c())

  for (g in 1:length(Species.list)) {
    result <- Species.data.x[(Species.list[g] == Species.data.x$Species1 &  Species.list[g] == Species.data.x$Species2),]

    #per species
    if (nrow(result)>3) {

      dm <- matrix(0, nrow=length(unique(c(result$Acc1,result$Acc2))), ncol=length(unique(c(result$Acc1,result$Acc2))))
      rownames(dm) <- unique(c(result$Acc1,result$Acc2))
      colnames(dm) <- unique(c(result$Acc1,result$Acc2))

      for (i in 1:nrow(result)) {
        row_id <- result[i, "Acc1"]
        col_id <- result[i, "Acc2"]
        dm[row_id, col_id] <- as.numeric(result[i, "ID"])
      } # end for i in rows

      per.species <- t(dm)+dm
      per.species[per.species == 0] <- NA

      per.species.med<-cbind(as.data.frame(apply(per.species, 2, median, na.rm = T)), Species.list[g])
      badones <- row.names(per.species.med[per.species.med[,1]< thres_iter[iter],])

      if(length(badones) > 0.5*length(unique(result[,2]))){ badones=c() }
      total_badones <- c(total_badones,badones)



    } else {

    } # end if >3

  }  #SPECIES FOR NEEDS TO END HERE

  input_dyn[[iteration]] <- input_dyn[[iterationp]][!(input_dyn[[iterationp]][,2] %in% total_badones | input_dyn[[iterationp]][,5] %in% total_badones),]

  print(iteration)

}  #end of threshold loop

write.table(total_badones, 'Badseqs.txt')
