ruleset Gossip {
  meta {
    use module Subscriptions
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }
  

  //Message management

  rule new_message{
    select when new message
    pre{
      //compile the data together
      partial_message = { "originator":event:attr("originator"),
                          "message": event:attr("message"),
                          "messageID": event:attr("messageID")
                        }
      rumor_message = {"Rumor": partial_message, "Endpoint":"Some URL"}.klog("rumor_message: ")
      originatorID = event:attr("messageID").split(re#:#)[0]
      //error check: do not add a new message that has the same messageID?
    }
    noop()
    fired{
      ent:originators := originators.defaultsTo([]).union([originatorID]);
      ent:messages := ent:messages.defaultsTo([{}]).union([rumor_message])
    }
  }

  rule clear_messages{
    select when clear messages
    noop()
    always{
      ent:originators:= [];
      ent:messages := []
    }
  }


  //Message communication

  rule onWant{
    select when want message
    noop()
  }

  rule onRumor{
    select when rumor package
    noop()
  }

  rule rumor_package{
    select when send rumor
    noop()
  }

  rule want_package{
    select when send want
    pre{
      subscriptions = Subscriptions:getSubscriptions().klog("subscriptions: ")
      keys = subscriptions.keys()
      subscriptions_not_empty = keys.length() > 0 
    }
    if subscriptions_not_empty then{ 
      //raise events to every subscribed pico
      noop()
    }
    else{
      noop()
    }
    fired{
    }
  }
}
