# Description:
#   What's does SpoonRocket have today?
#
# Dependencies:
#   "moment": "^2.6.0"
#
# Commands:
#   hubot spoonrocket - Pulls today's menu
#   hubot spoonrocket sf - Pulls today's San Francisco menu
#   hubot spoonrocket eastbay - Pulls today's East Bay menu
#
# Author:
#   jonursenbach

cheerio = require 'cheerio'
moment = require 'moment'

module.exports = (robot) =>
  robot.respond /spoonrocket( (sf|eastbay)?)?$/i, (msg) ->
    location = if msg.match[1] then msg.match[1].trim() else 'sf'
    now = moment().format('HH:MM')

    # https://api.spoonrocket.com/userapi/zones
    zones = {
        sf: {
          id: 2,
          name: "San Francisco"
        },
        eastbay: {
          id: 8,
          name: "East Bay"
        }
    }

    zone = zones[location]

    msg.http('https://api.spoonrocket.com/userapi/menu?zone_id=' + zone.id)
      .get() (err, res, body) ->
        return msg.send "Sorry, SpoonRocket doesn't like you. ERROR:#{err}" if err
        return msg.send "Unable to get today's menu: #{res.statusCode + ':\n' + body}" if res.statusCode != 200

        resp = JSON.parse(body)

        return msg.send "Sorry, SpoonRocket in " + zone.name + " is currently inactive." if !resp.active
        return msg.send "Sorry, SpoonRocket hasn't opened yet in " + zone.name + "." if now < resp.opening_time

        if now >= resp.closing_time && resp.closing_time != '00:00'
          return msg.send "Sorry, SpoonRocket is currently closed in " + zone.name + "."

        emit = 'Today\'s SpoonRocket menu is:' + "\n\n";
        menu = []

        for entry in resp.menu
          item = '· ' + entry.name + ' ($' + entry.price + '): ' + entry.description + ' (' + entry.properties + ')'
          if entry.qty <= 0 || entry.sold_out_for_the_day
            item += ' [SOLD OUT]'
          else if entry.sold_out_temporarily
            item += ' [Temporarily sold out]'
          else if entry.qty <= 10
            item += ' [Almost sold out!]'

          menu.push(item)

        emit += menu.join("\n")

        emit += "\n\n" + 'Order: https://www.spoonrocket.com/'

        msg.send emit
