// Description:
//   Watches root servers
//
// Dependencies:
//
//
// Configuration:
//  HUBOT_UPTIMEROBOT_APIKEY
//  HUBOT_UPTIMEROBOT_ALERTCONTACTID
//
// Commands:
//
//
// Notes:
//
//
// Author:
//   radius314
let utils = require('./utils.js');
let cron = require('cron');
const rootListUrl = "https://raw.githubusercontent.com/bmlt-enabled/aggregator/main/rootServerList.json";

module.exports = robot => {
  new cron.CronJob({
    cronTime: '00 45 * * * *', // checks every 15 mins
    onTick: () => {
      processMonitors(robot);
    },
    start: true
  });

  robot.hear(/how many roots.*/i, msg => {
    utils.requestGet(msg, `${rootListUrl}`, raw => {
      let roots = JSON.parse(raw);
      msg.send(`There are currently ${roots.length} roots.`);
    });
  });

  robot.respond(/show active monitors.*/i, msg => {
    getCurrentMonitors(msg);
  });

  robot.respond(/process monitors.*/i, msg => {
    processMonitors(msg);
  });
};

function processMonitors(msg) {
  getCurrentMonitors(msg, resMonitors => {
    let monitors = JSON.parse(resMonitors)['monitors'];
    utils.requestGet(msg, `${rootListUrl}`, resRoots => {
      let roots = JSON.parse(resRoots);
      if (monitors.length > 0) {
        for (let monitor of monitors) {
          if (roots.hasItem('rootURL', monitor['url'])) {
            roots.removeItem('rootURL', monitor['url'])
          } else {
            removeMonitor(msg, monitor['id']);
          }
        }
      }

      for (let root of roots) {
        addMonitor(msg, root['name'], root['rootURL'], () => {})
      }
    });
  });
}

Array.prototype.hasItem = (objName, url) => {
  for (let x = 0; x < this.length; x++) {
    if (objName[x][objName] === url) {
      return true;
    }
  }

  return false;
};

Array.prototype.removeItem = (objName, url) => {
  for (let x = 0; x < this.length; x++) {
    if (objName[x][objName] === url) {
      this.splice(x, 1);
    }
  }
};

function getCurrentMonitors(msg, cb) {
  uptimeRobotApiRequest(msg, "getMonitors", cb);
}

function addMonitor(msg, friendly_name, url, cb) {
  uptimeRobotApiRequest(
    msg,
    "newMonitor",
    {
      "type": 1,
      "friendly_name": friendly_name,
      "url": url,
      "alert_contacts": process.env["HUBOT_UPTIMEROBOT_ALERTCONTACTID"]
    },
    cb
  );
}

function removeMonitor(msg, id, cb) {
  uptimeRobotApiRequest(
    msg,
    "deleteMonitor",
    {
      "id": id
    },
    cb
  );
}


function uptimeRobotApiRequest(msg, uptimeRobotMethod, payload, cb) {
  let data = {
    ...{
      "api_key": process.env["HUBOT_UPTIMEROBOT_APIKEY"],
      "format": "json"
    },
    ...payload
  };
  utils.requestPost(
    msg,
    `https://api.uptimerobot.com/v2/${uptimeRobotMethod}`,
    data,
    cb !== null ? cb : () => void 0
  );
}
