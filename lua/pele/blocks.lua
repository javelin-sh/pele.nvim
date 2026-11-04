local M = {}
function M.parse(lines)
  local blocks, fence, start, source, mermaid = {}, nil, nil, {}, false
  for i, line in ipairs(lines) do
    local indent, run, info = line:match('^( *)([`~]+)(.*)$')
    local valid = run and #indent <= 3 and #run >= 3 and (run:match('^`+$') or run:match('^~+$'))
    if not fence and valid then
      fence, start, source = run, i, {}
      mermaid = info:match('^%s*mermaid%s*$') ~= nil
    elseif fence then
      if valid and run:sub(1, 1) == fence:sub(1, 1) and #run >= #fence and info:match('^%s*$') then
        if mermaid then table.insert(blocks, { row = math.max(start - 1, i - 2), source = table.concat(source, '\n') }) end
        fence = nil
      else
        table.insert(source, line)
      end
    end
  end
  return blocks
end
return M
