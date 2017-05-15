ruleset test3 {
  meta {
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }

  rule what_are_you{
    select when test something
    pre{
    }
    noop()
    fired{
    }
  }
}
