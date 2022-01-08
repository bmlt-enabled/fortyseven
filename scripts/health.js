// Description
//   health check
//
// Configuration:
//
//
// Commands:
//
//
// Notes:
//

module.exports = (robot) => {
  robot.router.get('/', (req, res) => res.status(200).end("ok"));
};
