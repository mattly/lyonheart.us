cheerio = require('cheerio')

getHtml = (page) -> page._htmlraw

extractFootnotes = (page, callback) ->
  if page._htmlraw.length is 0 then return callback(null, page)
  doc = cheerio.load(getHtml(page))
  footnotes = doc("div.footnotes")
  if footnotes.length > 0
    theFn = footnotes.find('li').first()
    while theFn.length > 0
      theFn.find('a').last().attr('rev','footnote')
      theFn = theFn.next()
    page.metadata.footnotes = "<ol>#{footnotes.find("ol").html()}</ol>"
    footnotes.remove()
    doc('a.footnoteRef')
      .attr('rel','footnote')
      .removeAttr('class')
    page._htmlraw = doc.html()
  # fix for typogr's smarty-faux-paus, doesn't belong here but setting up a separate renderer is a pain
  page._htmlraw = page._htmlraw.replace(/>&#8216;/,'>&#8217;','g')
  callback(null, page)

module.exports = (env, callback) ->

  options = env.config.footnoter or {}
  options.markdown or= 'MarkdownPage'

  class FootNoter extends env.plugins[options.markdown]
  FootNoter.fromFile = (filepath, callback) ->
    env.plugins[options.markdown].fromFile filepath, (err, page) ->
      if err then callback(err)
      else extractFootnotes(page, callback)

  env.registerContentPlugin 'pages', '**/*.*(markdown|mkd|md)', FootNoter
  callback()
