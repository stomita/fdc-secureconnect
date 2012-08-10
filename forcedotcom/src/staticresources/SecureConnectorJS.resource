(function($) {

  /**
   * Utility Functions
   */
  var console = this.console;
  if (typeof console === 'undefined') {
    console = {
      log: function(msg) {}
    };
  }
  
  function defineClass(definition, superClass) {
    var f = function() {
      if (this.init) this.init.apply(this, arguments);
    }
    if (superClass) {
      var subClass = function() {}
      subClass.prototype = superClass.prototype;
      f.prototype = new subClass;
      f.prototype.__super__ = superClass.prototype;
    }
    for (var prop in definition) {
      f.prototype[prop] = definition[prop];
    }
    return f;
  }
  
  function responder(callback) {
    var t = typeof callback;
    if (t === 'function') {
      return {
        onSuccess : function() { 
          var args = Array.prototype.slice.call(arguments);
          args.unshift(null);
          callback.apply(null, args);
        },
        onFailure : function(err) { 
          callback(err);
        }
      };
    } else if (t === 'object' && typeof callback.onSuccess === 'function') {
      return callback;
    } else {
      return null;
    }
  }
  
  /**
   * Cometd Subscriber Base Class
   */
  var SecureConnector = defineClass({

    init: function(config) {
      this.config = config = config || {};
      this.requestObjectType = config.requestObjectType || "SecureConnect__c";
      this.logLevel = config.logLevel;
      $.cometd.init({
        url: window.location.protocol + '//' + location.hostname + '/cometd/' + (this.config.version || 24.0),
        requestHeaders: { Authorization: 'OAuth ' + sforce.connection.sessionId }
      });
    },

    _subscribe: function(type) {
      var self = this;
      $.cometd.subscribe('/topic/' + this.config.topicName, function(message) {
        self._handle(message.data.sobject);
      });
    }

  });

  /**
   * Client
   */
  var SecureConnectorClient = defineClass({

    init: function(config) {
      this.__super__.init.call(this, config);
      this.config.topicName = this.config.topicName || "SecureConnectResponse";
      this._callbacks = {};
      this._subscribe();
    },

    request : function(type, req, callback) {
      if (!callback) {
        callback = req;
        req = null;
      }
      callback = responder(callback);
      var self = this;
      var r = new sforce.SObject(this.requestObjectType);
      r.RequestType__c = type;
      if (req) {
        r.Status__c = "REQUEST_WITH_DATA";
        r.RequestData__c = JSON.stringify(req);
      } else {
        r.Status__c = "REQUEST";
      }
      sforce.connection.create([r], responder(function(err, rets) {
        if (err || rets[0].success !== "true") {
          callback.onFailure(err);
        } else {
          console.log("request sent, id=" + rets[0].id);
          self._callbacks[rets[0].id] = callback;
        }
      }));
    },

    _handle : function(r, data) {
      var callback = this._callbacks[r.Id];
      if (!callback) return;
      console.log("response received, id=" + r.Id);
      var self = this;
      if (typeof data === 'undefined' && r.Status__c === 'RESPONSE_WITH_DATA') {
        sforce.connection.retrieve(
          "ResponseData__c", this.requestObjectType, [ r.Id ],
          responder(function(err, rets) {
            if (err) {
              return callback.onFailure(err);
            }
            var data = rets[0].ResponseData__c;
            if (data) {
              try {
                data = JSON.parse(data);
              } catch(e) { 
                data = null;
              }
            }
            console.log("fetched response data");
            console.log("code=" + r.ResponseCode__c);
            return callback.onSuccess(r.ResponseCode__c, data);
          })
        );
        return;
      }
      if (r.Status__c === 'ERROR') {
        callback.onFailure({ message : r.ResponseCode__c });
      } else {
        console.log("code=" + r.ResponseCode__c);
        callback.onSuccess(r.ResponseCode__c, data);
      }
    }

  }, SecureConnector);
  

  /**
   * Server
   */
  var SecureConnectorServer = defineClass({

    init: function(config) {
      this.__super__.init.call(this, config);
      this._listeners = {};
      this.config.topicName = this.config.topicName || "SecureConnectRequest";
      this._subscribe();
    },

    addListener : function(type, listener) {
      this._listeners[type] = listener;
    },

    _handle : function(r, data) {
      var listener = this._listeners[r.RequestType__c];
      if (!listener) return;
      console.log("request received, id=" + r.Id);
      var self = this;
      if (typeof data === 'undefined' && r.Status__c === 'REQUEST_WITH_DATA') {
        sforce.connection.retrieve(
          "RequestData__c", this.requestObjectType, [ r.Id ],
          responder(function(err, rets) {
            if (err) {
              return self._respond(r.Id, { type: '', error: err });
            }
            var data = rets[0].RequestData__c;
            if (data) {
              try {
                data = JSON.parse(data);
              } catch(e) { 
                data = null;
              }
            }
            console.log("fetched request data");
            return self._handle(r, data);
          })
        );
        return;
      }
      listener(data, responder(function(err, code, data) {
        self._respond(r.Id, err, code, data);
      }));
    },

    _respond : function(id, err, code, data) {
      var r = new sforce.SObject(this.requestObjectType);
      r.Id = id;
      if (err) {
        r.ResponseCode__c = err.code || err.message;
        r.ResponseData__c = JSON.stringify(err);
        r.Status__c = 'ERROR';
      } else {
        r.ResponseCode__c = code;
        if (data) {
          r.ResponseData__c = JSON.stringify(data)
          r.Status__c = 'RESPONSE_WITH_DATA';
        } else {
          r.Status__c = 'RESPONSE';
        }
      }
      sforce.connection.update([r], function(rets) {
        console.log("response sent, id=" + rets[0].id);
      });
    }

  }, SecureConnector);

  /* Synonym */
  SecureConnectorServer.prototype.on = SecureConnectorServer.prototype.addListner;
  
  /**
   * Exposing to Global Object
   */
  this.SecureConnector = {
    Client : SecureConnectorClient,
    Server : SecureConnectorServer
  };
  
})(jQuery);