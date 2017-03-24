ruleset Gossip {
  meta {
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }
  
  rule new_message{
    select when new message
    pre{
      //compile the data together
      partial_message = { "originator":event:attr("originator"),
                          "message": event:attr("message"),
                          "originatorID": event:attr("originatorID")
                        }
      rumor_message = {"Rumor": partial_message, "Endpoint":"Some URL"}
      //check for already existing message id
    }
    fired{
      ent:messages.defaultsTo([]).union([rumor_message])
    }
  }

  rule clear_messages{
    select when clear messages
    always{
      ent:messages := []
    }
  }
}
