const express = require('express')
const app = express()
const port = 3000

const mysql = require('mysql')
const connection = mysql.createConnection({host: "localhost", user: "example-user", password: "my_cool_secret", database: "dbcuration"})

let records_total = -1
connection.query('SELECT COUNT(*) AS total FROM its2_accessions', (err, rows, fields) => {records_total = rows[0].total})


app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.get('/api', (req, res) => {
  let start = parseInt(req.query["start"])
  let len = parseInt(req.query["length"])
  connection.query(
    `SELECT * FROM its2_accessions LIMIT ${len} OFFSET ${start}`,
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
