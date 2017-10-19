QuickSet ;
  n factor
  s factor("NOT A THING")=$$setDefault(0,factor("NOT A THING"),"default")
  s factor("NOT A THING")=$G(factor("NOT A THING"),$s(1:$$writeSomeStuff("hopefully this doesn't print twice")))
  n myVar
  s myVar=$G(myVar,$s(1:$$writeSomeStuff("this out to print once and then again")))
  s myVar=$G(myVar,$s(1:$$writeSomeStuff("this out to print once and then again")))
  ; s myVar=$G(myVar,$$writeSomeStuff("this out to print once and then again"))
  q
;
