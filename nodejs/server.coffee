mysql = require "mysql"
async = require "async"
sf    = require "node-salesforce"
SecureConnector = require "./secure-connector"

sfConn = new sf.Connection()
sfUsername = process.env.SF_USERNAME
sfPassword = process.env.SF_PASSWORD

mysqlCli = mysql.createClient
  host: process.env.MYSQL_SERVER_NAME || "localhost"
  port: process.env.MYSQL_SERVER_PORT || 3306
  database: process.env.MYSQL_DATABASE
  user: process.env.MYSQL_USER
  password: process.env.MYSQL_PASSWORD

##
# Connect to salesforce streaming API
##
sfConn.login sfUsername, sfPassword, (err, res) ->
  return console.log err.message if err
  console.log "logged in"
  server = new SecureConnector.Server(sfConn)

  # Hello world
  server.addListener "hello", (username, callback) ->
    console.log "hello", username
    callback null, "success", "Hello, " + (username || "World")

  # SQL Query 
  # NOTE: This is demo only and never use in production code because it causes SQL injection.
  server.addListener "query", (sql, callback) ->
    console.log "query", sql
    mysqlCli.query sql, (err, results) ->
      if err
        console.log err.message
        return callback err.message
      callback null, "success", results

  # Propagation from Apex
  server.addListener "opps/propagate", (opps, callback) ->
    console.log "opps/propagate", opps
    async.map opps, (opp, cb) ->
      params = [ opp.Id, opp.Name, Number(opp.Amount), opp.CloseDate ]
      if opp.ExtId
        params.push(opp.ExtId)
        sql = "UPDATE billing SET opp_id = ?, name = ?, amount = ?, close_date = ? WHERE id = ?"
      else
        sql = "INSERT INTO billing (opp_id, name, amount, close_date) VALUES (?, ?, ?, ?)"
      query = mysqlCli.query sql, params, (err, res) ->
        console.log query.sql if err
        cb(err, res)
    , (err, results) ->
      if err
        console.log err
        return callback err.message
      ids = results.map (r) -> if r.insertId then String(r.insertId) else null
      console.log ids
      callback null, "success", ids
  

