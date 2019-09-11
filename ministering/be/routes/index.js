var express = require('express');
var router = express.Router();
import fs from 'fs';

/* GET home page. */
router.get('/', function(req, res, next) {
  res.json({ message: 'hello, there; what shall we do today?' });
});

router.get('/sw-v1.js', function(req, res, next) {
  res.json({});
});

const path = '/Users/dcvezzani/personal-projects/ward/ministering/be'

router.get('/yearbook-photo-attributes', function(req, res, next) {
  const data = fs.readFileSync(`${path}/yearbook-photo-attributes.dat`)
  res.json({ message: 'fetching all photo attributes', data: JSON.parse(data.toString()) });
});

router.post('/yearbook-photo-attributes', function(req, res, next) {
  console.log(">>>req", req.body)
  fs.writeFileSync(`${path}/yearbook-photo-attributes.dat`, JSON.stringify(req.body.data))
  res.json({ message: 'saved all photo attributes' });
});

router.put('/yearbook-photo-attributes', function(req, res, next) {
  console.log(">>>req", req.body)
  fs.writeFileSync(`${path}/yearbook-photo-attributes.dat`, '')
  res.json({ message: 'saved attributes for one photo' });
});


module.exports = router;
