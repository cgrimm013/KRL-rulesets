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
    
    get_filtered_map = function(){
      ent:messageIDs.defaultsTo({}).map(
  function(v,k){
    [v.filter(function(x){
      not(v >< (x+1))
      })[0]
    ]
  }
      )
    }

    create_package = function(messageID){
      ent:messages.defaultsTo([]).filter(
        function(v) {
          v{["Rumor","messageID"]} == messageID
        })[0]
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
      ent:messageIDs{[originatorID]} := newArray;
      raise want event "poke"
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
    always{
      raise rumor event "need"
        attributes event:attrs();
      raise rumor event "missing"
        attributes event:attrs()
    }
  }

  /*
    The following two rules will break the infinite loop. The final foreach in each
    ruleset will be empty when one pico contains all the messages the other pico contains,
    thus not sending anymore want messages
  */

  //this rule follows the logic: "everthing I have, but you do not"
  rule rumor_need{
    select when rumor need
      foreach ent:messageIDs setting(value,originator)
        foreach value.defaultsTo([]).difference(event:attr("want"){[originator]}.defaultsTo([])).klog("Value: ") setting(sequence_number)
    pre{
      needToSend = event:attr("want"){[originator]}[0].defaultsTo(-1) < sequence_number
    }
    if needToSend then
    noop()
    fired{
      //send the information to the desired pico
      raise rumor event "package"
        attributes { "endpoint": event:attr("endpoint"),
                     "messageID": originator + ":" + sequence_number.as("String")
                   }
    }
  }

  //the logic: "if you have something I do not, i'll send you a want message"
  rule rumor_missing{
    select when rumor missing
      foreach event:attr("want") setting(value,originator)
        foreach value.difference(ent:messageIDs{[originator]}.defaultsTo([])) setting(sequence_number)
    pre{
    }
    event:send( { "eci": event:attr("endpoint"), 
                    "eid": "anything",
                    "domain": "want", 
                    "type": "message",
                    "attrs": {"want": get_filtered_map(),
                              "endpoint": meta:eci
                             } 
                  } )
    fired{
      
    }
  }

  rule onRumor{
    select when rumor message
    pre{
    }
    noop()
    fired{
    }
  }

  rule rumor_package{
    select when rumor package
    pre{
      a = event:attr("endpoint").klog("rumor_package_endpt: ")
      messageID = event:attr("messageID").klog("rumor_package_id: ")
      map_to_send = create_package(messageID).klog("messageID: ")
    }
    event:send( { "eci": event:attr("endpoint"), 
                    "eid": "anything",
                    "domain": "message", 
                    "type": "new",
                    "attrs": {"originator": map_to_send{["Rumor","originator"]},
                              "message": map_to_send{["Rumor","message"]},
                              "messageID": map_to_send{["Rumor","messageID"]},
                              "endpoint": map_to_send{["Endpoint"]}
                             }
                  } )
    fired{
    }
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
      not_empty = ent:messageIDs.defaultsTo({}).keys().length() > 0
      d = not_empty.klog("not_empty:" )
      e = get_filtered_map().klog("filteredMap: ")
    }
    if not_empty then
    event:send( { "eci": eci_to_poke, 
                    "eid": "anything",
                    "domain": "want", 
                    "type": "message",
                    "attrs": {"want": get_filtered_map(),
                              "endpoint": meta:eci
                             } 
                  } )
    fired{
      //do nothing for now
    }
  }
}
