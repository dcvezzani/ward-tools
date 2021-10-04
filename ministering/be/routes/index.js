var express = require('express');
var router = express.Router();
import fs from 'fs';
// const {execSync} = require('child_process');
const util = require('util');
const exec = util.promisify(require('child_process').exec);
const { spawn } = require( 'child_process' );
import db from '../db'
import { v4 as uuidv4 } from 'uuid';
var cors = require('cors')
const worker = require('../workers/queue')

/* GET home page. */
router.get('/', function(req, res, next) {
  res.json({ message: 'hello, there; what shall we do today?' });
});

router.get('/sw-v1.js', function(req, res, next) {
  res.json({});
});

const path = '/Users/dcvezzani/personal-projects/ward/ministering/be'
const photosPath = '/Users/dcvezzani/personal-projects/ward/photos'

// router.get('/photos/:personFile', function(req, res, next) {
//   const data = fs.readFileSync(`${photosPath}/${req.params.personFile}`)
//   const img = toBase64(data)

//   res.writeHead(200, {
//      'Content-Type': 'text/plain',
//      'Content-Length': img.length
//   });

//   res.end(img); 
// });

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

// async function sendText({recipients, message}) {
//   console.log(">>>recipients", recipients)
//   return new Promise((resolve, reject) => {
//     const cmd = spawn( './scripts/send-text.sh', [ toBase64(message), `${recipients}` ] );
//     const data = {}

//     cmd.stdout.on( 'data', _data => data.stdout = `${_data}` );
//     cmd.stderr.on( 'data', _data => data.stderr = `${_data}` );
//     cmd.on( 'close', code => {
//       console.log(">>>data", data)
//       return resolve({ code, data })
//     });
//   })
// }

// router.post('/send-text-v01', async function(req, res, next) {
//   console.log(">>>req", req.body)

//   // const cmdRes = await ls();
//   // const cmdRes = {}
//   const cmdRes = await sendText({recipients: req.body.recipients.map(entry => `${entry}`).join(' '), message: req.body.message});
//   res.json({ message: 'done', ...cmdRes });
// });

router.get('/get-next-in-queue', cors(), async function(req, res, next) {
  const responsePayload = await db.getUnprocessedJobsFor('text-message')
  .then(payload => {
    return Promise.resolve({ message: 'done', count: payload.length, payload })
  })
  .catch(err => {
    return Promise.resolve({ message: `Unable to get unprocessed jobs for text-message type`, error: err })
  })

  res.json(responsePayload);
});

// router.options('/send-text', cors())
router.post('/send-text', cors(), async function(req, res, next) {
  const {jobGroupId} = req.query
  const responsePayload = await worker.processTextMessageJobs(jobGroupId)
  .then(payload => {
    return Promise.resolve({ status: 200, message: 'done', payload })
  })
  .catch(err => {
    console.error(`Unable to process text message jobs; ${JSON.stringify(err)}`)
    return Promise.resolve({ status: 500, message: 'done', err })
  })
  res.status(responsePayload.status).json(responsePayload);
});

// router.options('/queue-text', cors())
router.post('/queue-text', cors(), async function(req, res, next) {
  console.log(">>>req", req.body)

  await db.clearTextMessagesFromQueue('text-message')
  
  const jobGroupId = uuidv4()
  const textMessageJobs = req.body.recipients.map(entry => {
    return {
      type: 'text-message',
      jobGroupId,
      payload: JSON.stringify({message: req.body.message, ...entry}), // , phone: '2097569688'
    }
  })

  let responseStatus
  const dbRes = await db.addTextMessagesToQueue(textMessageJobs)
  // .then(payload => {
  //   return Promise.reject(new Error("xxx"))
  //   return Promise.resolve(payload)
  // })
  .catch(err => {
    const message = `Unable to add text messages to queue: ${JSON.stringify({message: err.message, stack: err.stack})}`
    console.error(`${message}; ${JSON.stringify(textMessageJobs)}`)
    responseStatus = 500
    return { error: message }
  })
  // const cmdRes = await ls();
  // const cmdRes = {}
  // const cmdRes = await sendText({recipients: req.body.recipients.map(entry => `${entry}`).join(' '), message: req.body.message});

  res.status(responseStatus || 200).json({ message: 'done', ...dbRes });
});


module.exports = router;
