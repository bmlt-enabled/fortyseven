// Description:
//   Tomato utilities
//
// Dependencies:
//
//
// Configuration:
//
//
// Commands:
//   hubot tomato last import - returns the time of the last sync
//   what region has <area> - returns the region a given area is in
//   hubot meetings in tomato - returns the number of meetings in tomato.
//
// Notes:
//
//
// Author:
//   radius314
var moment = require('moment');
var utils = require('./utils.js')

module.exports = robot => {
  var tomatoBaseUrl = 'https://aggregator.bmltenabled.org';

  robot.respond(/tomato last import/i, msg => {
    utils.requestGet(robot,
      `${tomatoBaseUrl}/rest/v1/rootservers/?format=json`,
      res => {
        let maxTime = null;
        for (item of JSON.parse(res)) {
          if (maxTime == null || Date.parse(item['last_successful_import']) < maxTime) {
            maxTime = Date.parse(item['last_successful_import'])
          }
        }

        msg.send("The last 🍅 import was at: " + moment(maxTime).format("MMMM Do YYYY, h:mm:ss a") + " UTC");
      });
  });

  robot.hear(/what region (has|is) (.*[^\?])/i, msg => {
    let found = false;
    let match = msg.match[2];

    utils.requestGet(robot,
      `${tomatoBaseUrl}/main_server/client_interface/json/?switcher=GetServiceBodies`,
      res => {
        for (item of JSON.parse(res)) {
          if (item['type'] === 'AS'
            && item['name'].toLowerCase().indexOf(match.toLowerCase()) >= 0) {
            for (let parent of JSON.parse(res)) {
              if (parent['id'] === item['parent_id']) {
                msg.send(`🍅 says there is an area called ${item['name']} in ${parent['name']}.`);
                found = true;
              }
            }
          }
        }

        if (!found) msg.send(`🍅 has no idea what ${match} is.`);
      });
  });

  robot.respond(/meetings in tomato/i, msg => {
    const currentWorldWideCount = 76075; // As of the regional map April 2020
    msg.send(`Hold on a moment, I'm asking 🍅...`)
    utils.requestGet(robot,
      `${tomatoBaseUrl}/rest/v1/meetings/?format=json`,
      res => {
        tomatoMeetings = JSON.parse(res);
        meetingCount = tomatoMeetings['count'].toLocaleString();
        coverageMetric = Math.floor((tomatoMeetings['count'] / currentWorldWideCount) * 100);
        msg.send(`There are ${meetingCount} meetings in 🍅, which is ${coverageMetric}% of the ${currentWorldWideCount.toLocaleString()} meetings in the world.`);
      });
  });
};
