ruleset Gossip {
  meta {
    use module Subscriptions
    shares __testing, get_messages
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
    get_messages = function(){
      ent:messages
    }
  }
  

  //Message management

  rule new_message{
    select when message new
    pre{
      //compile the data together
      partial_message = { "originator":event:attr("originator"),
                          "message": event:attr("message"),
                          "messageID": event:attr("messageID")
                        }
      endpoint = event:attr("endpoint")
      rumor_message = {"Rumor": partial_message, "Endpoint":endpoint}.klog("rumor_message: ")
      messageID_array = event:attr("messageID").split(re#:#)
      originatorID = messageID_array[0].as("String")
      sequenceValue = messageID_array[1].as("Number")
      newArray = ent:messageIDs{[originatorID]}.defaultsTo([]).union([sequenceValue]).klog("newArray: ")
      //error check: do not add a new message that has the same messageID?
    }
    noop()
    fired{
      ent:endpoints := ent:endpoints.defaultsTo([]).union([endpoint]);
      ent:originators := ent:originators.defaultsTo([]).union([originatorID]);
      ent:messages := ent:messages.defaultsTo([{}]).union([rumor_message]);
      ent:messageIDs := ent:messageIDs.defaultsTo({});//in case messageIDs does not yet exist
      ent:messageIDs{[originatorID]} := newArray
    }
  }

  rule clear_messages{
    select when message clear
    noop()
    always{
      ent:originators:= [];
      ent:messages := [];
      ent:endpoints := [];
      ent:messageIDs := {}
    }
  }


  //Message communication

  rule onWant{
    select when want message
    pre{
      temp2 = meta:eci.klog("Pico's eci: ")
      temp = event:attrs().klog("want_message")
    }
    noop()
  }

  rule onRumor{
    select when rumor message
    noop()
  }

  rule rumor_package{
    select when rumor package
    noop()
  }

  rule want_poke{
    select when want poke
    pre{
      //dont poke subscriptions if there are none!
      subscriptions = Subscriptions:getSubscriptions().klog("subscriptions: ")
      keys = subscriptions.keys()
      subscriptions_not_empty = keys.length() > 0 
    }
    if subscriptions_not_empty then 
      noop()
    fired{
      //send want events to every subscribed pico
      raise want event "subscriptions"  
        attributes subscriptions
    }
  }

  rule wants{
    select when want subscriptions
    foreach event:attrs() setting(value,name)
    pre{
      b = value.klog("value: ")
      c = name.klog("name: ")
      //obtain the sending address eci
      eci_to_poke = value{["attributes","outbound_eci"]}.klog("eci: ")
      want_message = {"want": ent:messageIDs}
    }
    event:send( { "eci": eci_to_poke, 
                    "eid": "anything",
                    "domain": "want", 
                    "type": "message",
                    "attrs": want_message 
                  } )
    always{
      //do nothing for now
    }
  }
}
