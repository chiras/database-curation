const express = require('express')
const app = express()
const port = 3000

const mysql = require('mysql')
const connection = mysql.createConnection({host: "localhost", user: "example-user", password: "my_cool_secret", database: "dbcuration"})

let records_total = -1
connection.query('SELECT COUNT(*) AS total FROM its2_accessions', (err, rows, fields) => {records_total = rows[0].total})

const columns=["Accession", "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species", "Status"]

app.get('/', (req, res) => {
  res.send('Hello World!')
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
  connection.query(
    `SELECT * FROM its2_accessions ORDER BY ${order_cols} LIMIT ${len} OFFSET ${start}`,
    (err, rows, fields) => {
	    //console.log(req)
      res.json({
        draw: parseInt(req.query["draw"]),
	recordsTotal: records_total,
	recordsFiltered: records_total,
	data: rows
      })
    }
  );
})

app.use(express.static('public'))

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
