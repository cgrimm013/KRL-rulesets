ruleset app_section_collection{
  meta{
    use module io.picolabs.pico alias wrangler
    shares __testing, showChildren
  }

  global{
    showChildren = function() {
    wrangler:children()
    }

    nameFromID = function(section_id) {
    "Section " + section_id + " Pico"
    }
    
    __testing = { "events":  [ { "domain": "section", "type": "needed", "attrs": [ "section_id" ] } ],
                  "queries": [{"name": "showChildren"}] }
  }

  rule collection_empty {
    select when collection empty
    always {
      ent:sections := {}
    }
  }

  rule section_already_exists {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if exists then
      send_directive("section_ready")
        with section_id = section_id
  }

  rule section_needed {
  select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< id
    }
    if not exists
    then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(section_id),
                     "color": "#FF69B4",
                     "section_id": section_id }
    }
  }

}
