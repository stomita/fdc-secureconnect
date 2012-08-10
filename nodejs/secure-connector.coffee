sf = require "node-salesforce"

###
  Cometd Subscriber Base Class
###
REQUEST_TOPIC_NAME = "SecureConnectRequest"
RESPONSE_TOPIC_NAME = "SecureConnectResponse"
SOBJECT_NAME = "SecureConnect__c"

class SecureConnector
  constructor: (@conn, @config = {}) ->

  _subscribe: (topicName) ->
    @conn.topic(topicName).subscribe (data) => @_handle(data.sobject)

###
###
class SecureConnectorClient extends SecureConnector
  constructor: (@conn, @config = {}) ->
    super conn, config
    @_callbacks = {}
    @_subscribe(RESPONSE_TOPIC_NAME)

  request : (type, req, callback) ->
    unless callback
      callback = req
      req = null
    record =
      RequestType__c : type
    if req?
      Status__c : "REQUEST_WITH_DATA"
      RequestData__c : JSON.stringify(req)
    else
      Status__c : "REQUEST"

    @conn.sobject(SOBJECT_NAME).create record, (err, ret) =>
      if err || !ret.success
        callback err
      else
        console.log "request sent, id=#{ret.id}"
        @_callbacks[ret.id] = callback

  _handle : (r, data) ->
    callback = @_callbacks[r.Id]
    return unless callback
    console.log "response received, id=#{r.Id}"
    if not data? && r.Status__c is 'RESPONSE_WITH_DATA'
      @conn.sobject(SOBJECT_NAME).retrieve r.Id, (err, rec) =>
        return callback(err) if err
        data = rec.ResponseData__c
        if data
          try
            data = JSON.parse(data)
          catch e
            data = null
        console.log("fetched response data")
        console.log("code=#{r.ResponseCode__c}")
        callback(null, r.ResponseCode__c, data)
    else if r.Status__c is'ERROR'
      callback( message : r.ResponseCode__c )
    else
      console.log("code=#{r.ResponseCode__c}")
      callback(null, r.ResponseCode__c, data)

###

###
class SecureConnectorServer extends SecureConnector
  constructor: (@conn, @config) ->
    super conn, config
    @_listeners = {}
    @_subscribe(REQUEST_TOPIC_NAME)

  addListener : (type, listener) ->
    @_listeners[type] = listener

  _handle : (r, data) ->
    listener = @_listeners[r.RequestType__c]
    return unless listener
    console.log("request received, id=#{r.Id}")
    if not data? && r.Status__c is 'REQUEST_WITH_DATA'
      @conn.sobject(SOBJECT_NAME).retrieve r.Id, (err, rec) =>
        return @_respond(r.Id, { type: '', error: err }) if err
        data = rec.RequestData__c
        if data
          try
            data = JSON.parse(data)
          catch e
            data = null
        console.log("fetched request data")
        @_handle(r, data)
      return
    listener data, (err, code, data) => @_respond(r.Id, err, code, data)

  _respond : (id, err, code, data) ->
    r =
      Id: id
    if err
      r.ResponseCode__c = err.code || err.message
      r.ResponseData__c = JSON.stringify(err)
      r.Status__c = 'ERROR'
    else
      r.ResponseCode__c = code
      if data
        r.ResponseData__c = JSON.stringify(data)
        r.Status__c = 'RESPONSE_WITH_DATA'
      else
        r.Status__c = 'RESPONSE'
    @conn.sobject(SOBJECT_NAME).update r, (err, ret) =>
      console.log("response sent, id=#{ret.id}")

### Synonym ###
SecureConnectorServer.prototype.on = SecureConnectorServer.prototype.addListner
  
###
 Exposing to Global Object
###
module.exports =
  Client : SecureConnectorClient
  Server : SecureConnectorServer

