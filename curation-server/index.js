const express = require('express')
const app = express()
const port = 3000

const mysql = require('mysql')
const connection = mysql.createConnection({host: "db", user: "example-user", password: "my_cool_secret", database: "dbcuration"})

// keepalive derived from https://stackoverflow.com/q/40430964/4969760
const keepalive = () => {
  connection.query('SELECT 1 + 1 AS solution', (err) => {if(err){console.log(err)}})
}
setInterval(keepalive, 180000) // 30 minutes

let records_total = -1
connection.query('SELECT COUNT(*) AS total FROM its2_accessions', (err, rows, fields) => {
  if(err){console.log(err)}
  records_total = rows[0].total
})

let makeQuery = (res, draw, search, order_cols, len, start, records_total, records_filtered) => connection.query(
  `SELECT * FROM its2_accessions ${search} ORDER BY ${order_cols} LIMIT ${len} OFFSET ${start}`,
  (err, rows, fields) => {
    if(err){console.log(err)}
    res.json({
      draw: draw,
      recordsTotal: records_total,
      recordsFiltered: records_filtered,
      data: rows
    })
  }
);

const columns=["Accession", "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species", "Status"]
const onlyLettersOrNumberPattern = /^[A-Za-z0-9 ]+$/

app.get('/', (req, res) => {
  res.sendFile('public/overview.html', {root: __dirname})
})

app.get('/api', (req, res) => {
  //console.log(req.query)
  let start = parseInt(req.query["start"])
  let len = parseInt(req.query["length"])
  let order_cols = req.query["order"].map(
	  x => [req.query["columns"][parseInt(x["column"])]["data"], x["dir"].toUpperCase()]
      ).filter(
	  x => columns.includes(x[0])
      ).map(
	  x => x.join(" ").replace("Order", "`Order`")
      ).join(", ")
  let search = "";
  let records_filtered = records_total
  let userSearch = req.query["search"]["value"]
  let draw = parseInt(req.query["draw"])
  if(userSearch && userSearch.match(onlyLettersOrNumberPattern)){
    search = `WHERE CONCAT_WS(',',${columns.join(",").replace("Order", "`Order`")}) LIKE '%${userSearch}%'`
    records_filtered = connection.query(`SELECT COUNT(*) AS c FROM its2_accessions ${search}`, (err, rows, fields) => {
      if(err){
        console.log(err)
      }
      records_filtered=rows[0].c
      makeQuery(res, draw, search, order_cols, len, start, records_total, records_filtered)
    })
  } else {
    makeQuery(res, draw, search, order_cols, len, start, records_total, records_filtered)
  }
})

app.use(express.static('public'))

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
