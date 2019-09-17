var express = require('express');
var router = express.Router();
import fs from 'fs';
// const {execSync} = require('child_process');
const util = require('util');
const exec = util.promisify(require('child_process').exec);
const { spawn } = require( 'child_process' );


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

async function ls_1() {
  const execRes = await exec('ls');
  console.log(">>>execRes", execRes)
  const { stdout, stderr } = execRes
  console.log('stdout:', stdout);
  console.log('stderr:', stderr);
}

async function ls() {
  return new Promise((resolve, reject) => {
    const ls = spawn( 'ls', [ '-lh', '.' ] );
    const data = {}

    ls.stdout.on( 'data', _data => {
        data.stdout = `${_data}`
        // console.log( `stdout: ${_data}` );
    } );

    ls.stderr.on( 'data', _data => {
        data.stderr = `${_data}`
        // console.log( `stderr: ${_data}` );
    } );

    ls.on( 'close', code => {
        console.log( `child process exited with code ${code}` );
        resolve({ code, data })
    } );
  })
}

const toBase64 = (str) => {
  return Buffer.from(str).toString('base64');
};

async function sendText({recipients, message}) {
  return new Promise((resolve, reject) => {
    const cmd = spawn( './scripts/send-text.sh', [ toBase64(message), `${recipients}` ] );
    const data = {}

    cmd.stdout.on( 'data', _data => data.stdout = `${_data}` );
    cmd.stderr.on( 'data', _data => data.stderr = `${_data}` );
    cmd.on( 'close', code => resolve({ code, data }) );
  })
}

router.post('/send-text', async function(req, res, next) {
  console.log(">>>req", req.body)

  // const cmdRes = await ls();
  // const cmdRes = {}
  const cmdRes = await sendText({recipients: req.body.recipients.join(' '), message: req.body.message});
  res.json({ message: 'done', ...cmdRes });
});


module.exports = router;
