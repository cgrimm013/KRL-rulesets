ruleset app_section_collection{
  meta{
    shares __testing
  }
  global{
    nameFromID = function(section_id) {
    "Section " + section_id + " Pico"
    }
    
    __testing = { "events":  [ { "domain": "section", "type": "needed", "attrs": [ "section_id" ] } ] }
  }

  rule section_needed {
  select when section needed
  pre {
    section_id = event:attr("section_id")
    exists = ent:sections >< section_id
    eci = meta:eci
  }
  if exists then
    send_directive("section_ready")
      with section_id = section_id
  fired {
  } else {
    ent:sections := ent:sections.defaultsTo([]).union([section_id]);
    raise pico event "new_child_request"
      attributes { "dname": nameFromID(section_id), "color": "#FF69B4" }
  }
}
}
