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
      //check for already existing message id
      //compile the data together
      partial_message = { "originator":event:attr("originator"),
                          "message": event:attr("message"),
                          "originatorID": event:attr("originatorID")
                        }
      rumor_message = {"Rumor": partial_message, "Endpoint":}
    }
    fired{
      ent:messages.defaultsTo([])
    }
  }
}
