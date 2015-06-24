# Description:
#   Generates an image macro using http://memegen.link/
#
# Commands:
#   hubot macro templates - Lists all the templates available
#   hubot macro <template> : <header> - <footer> - Generates an image macro from the template specified.
#   hubot macro wtf <template> - Returns link to a description of the template

templates = undefined

loadTemplates = (robot, callback) ->
  robot.http('http://memegen.link/templates/').get() (err, rs, body) ->
      if !err
        templates = {}
        rawTemplates = JSON.parse(body)
        for key, value of rawTemplates
          templates[value.match(/http:\/\/memegen.link\/templates\/(.*)/)[1]] = key
      callback err, rs, body

sendTemplates = (res) ->
  message = ""
  for key, value of templates
    message += "#{value}: #{key}\n"
  res.send message

getTemplate = (template) ->
  for key, value of templates
    if key.toLowerCase() == template.toLowerCase() or value.toLowerCase() == template.toLowerCase()
      return key

handleMacro = (res, uriTemplate, header, footer) ->
  uriHeader = encodeURI(header.replace(/\s/g, '-')).replace(/'/g, '%27')
  uriFooter = encodeURI(footer.replace(/\s/g, '-')).replace(/'/g, '%27')
  res.send "http://memegen.link/#{uriTemplate}/#{uriHeader}/#{uriFooter}.jpg"

handleWtf = (robot, res, uriTemplate) ->
  robot.http("http://memegen.link/templates/#{uriTemplate}").get() (err, rs, body) ->
    if err
      res.send "#{err}"
    else
      template = JSON.parse(body)
      res.send template.description

module.exports = (robot) ->
  robot.respond /macro templates/i, (res) ->
    if templates
      sendTemplates res
    else
      loadTemplates robot, (err, rs, body) ->
        if err
          res.send "#{err}"
        else
          sendTemplates res

  robot.respond /macro (.*) : (.*) - (.*)/i, (res) ->
    template = res.match[1]
    if templates and uriTemplate = getTemplate template
      handleMacro res, uriTemplate, res.match[2], res.match[3]
    else
      loadTemplates robot, (err, rs, body) ->
        if err
          res.send "#{err}"
        else if uriTemplate = getTemplate template
          handleMacro res, uriTemplate, res.match[2], res.match[3]
        else
          res.send "No macro: #{template}"

  robot.respond /macro wtf (.*)/i, (res) ->
    template = res.match[1]
    if templates and uriTemplate = getTemplate template
      handleWtf robot, res, uriTemplate
    else
      loadTemplates robot, (err, rs, body) ->
        if err
          res.send "#{err}"
        else if uriTemplate = getTemplate template
          handleWtf robot, res, uriTemplate
        else
          res.send "No macro: #{template}"