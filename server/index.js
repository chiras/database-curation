const express = require('express')
const app = express()
const port = 3000

const mysql = require('mysql')
const connection = mysql.createConnection({host: "localhost", user: "example-user", password: "my_cool_secret", database: "dbcuration"})

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.get('/api', (req, res) => {
  connection.query(
    'SELECT * FROM its2_accessions LIMIT 10',
    (err, rows, fields) => {
      res.json(rows)
    }
  );
})

app.use(express.static('public'))

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
