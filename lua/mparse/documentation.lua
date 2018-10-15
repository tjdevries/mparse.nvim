local inc = require('mparse.incremental')

local doc = {}

local split = function(str)
  lines = {}
  for s in str:gmatch("[^\r\n]+") do
      table.insert(lines, s)
  end
  return lines
end

local example = [[
  ;---------
  ; NAME:         GetMedDispensesInfo
  ; SCOPE:        PUBLIC
  ; DESCRIPTION:  Gets the medication dispense data for the given URIs in the context array.
  ; PARAMETERS:
  ;   a (I,REQ) - Example one
  ;   b (I,OPT) - Another input
  ;   c (O,OPT) - An output function
  ; RETURNS: Some variable
  ;-----
myFunction(a,b,c) ;
  n myVar
  s myVar=myVar
  s c=a+b+1
  q myVar
]]


doc.get_doc_lines = function(s)
  local lines = split(s)
  local sections, section_lines = doc.get_sections(lines)

  local attributes = {}
  local parsing_params = false

  for _, current_section in ipairs(section_lines) do
    for _, attr in ipairs(current_section) do
      -- print('_', _, 'attr:', attr)
      local attr_result = string.match(attr, '; (.-):')
      print(attr_result)

      if attr_result == 'PARAMETERS' then
        parsing_params = true
      elseif attr_result ~= nil then
        parsing_params = false

        attr_value = string.match(attr, ':%s+(.+)')
        print('Value: ', attr_value)
        attributes[attr_result] = attr_value
      elseif parsing_params then
        if attributes['PARAMETERS'] == nil then
          attributes['PARAMETERS'] = {}
        end

        table.insert(attributes['PARAMETERS'], attr)
      end

    end
  end

  print(require('inspect')(attributes))

  return section_lines
end

doc.get_sections = function(lines)
  local sections = {}
  local section_lines = {}

  local searching_for_start = true
  for index, line in ipairs(lines) do
    if string.match(line, '  ;----') then
      if searching_for_start then
        searching_for_start = false
        table.insert(sections, { index })
        table.insert(section_lines, { })
      else
        searching_for_start = true
        table.insert(sections[#sections], index)
      end
    else
      if not searching_for_start then
        table.insert(section_lines[#section_lines], line)
      end
    end
  end

  return sections, section_lines
end

print(require('inspect')(doc.get_doc_lines(example)))
