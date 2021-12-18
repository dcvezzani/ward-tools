import db from '../db'
const { spawn } = require( 'child_process' );

const toBase64 = (str) => {
  return Buffer.from(str).toString('base64');
};

function sendIndividualText({name, phone, message}) {
  console.log(">>>sendIndividualText [1], {name, phone, message}", {name, phone, message})
  // return Promise.resolve({message: 'Processed', payload: {name, phone, message}})

  if (!name) return Promise.reject(new Error(`Validation error: name required (${JSON.stringify(name)})`))
  if (!phone) return Promise.reject(new Error(`Validation error: phone required (${JSON.stringify(phone)})`))
  if (phone.length != 10) return Promise.reject(new Error(`Validation error: phone format; no dashes, 10 characters (${JSON.stringify(phone)})`))
  if (!message) return Promise.reject(new Error(`Validation error: message required (${JSON.stringify(message)})`))

  return new Promise((resolve, reject) => {
    const cmd = spawn( './scripts/send-individual-text.sh', [ toBase64(message), name, phone ] );
    const data = {}

    cmd.stdout.on( 'data', _data => data.stdout = `${_data}` );
    cmd.stderr.on( 'data', _data => data.stderr = `${_data}` );
    cmd.on( 'close', code => {
      console.log(">>>sendIndividualText [2], data", data)
      return resolve({ code, data, name, phone, message })
    });
    cmd.on( 'error', (...args) => {
      console.error(">>>error", args)
      return resolve({ error: args, name, phone, message })
    });
  })
}

const processJob = async (job) => {
  const {id: job_id, type, jobGroupId, payload, created_at} = job
  
  // console.log(">>>db.getUnprocessedJobForId(job_id).first()", db.getUnprocessedJobForId(job_id).first().toSQL())
  const alreadyProcessed = await db.getUnprocessedJobForId(job_id).first()
  .then(payload => Promise.resolve(!payload))
  .catch(err => Promise.resolve(false))
  // console.log(">>>alreadyProcessed", alreadyProcessed)

  if (alreadyProcessed) {
    try {
      console.warn("WARN: Job has already been processed", JSON.stringify(job))
    } catch (err) {}
    return false
  }

  await db.processJob({id: job_id, state: 'begin'})
  .catch(err => {
    const message = `Unable to mark job as processed:begin; ${JSON.stringify(job)}`
  })
  
  let sendTextResponse = {}
  try {
    const {message, lastName: name, phone} = JSON.parse(payload)
    sendTextResponse = await sendIndividualText({name, phone, message})
    sendTextResponse.success = true
  } catch(err) {
    const message = `Unable to process job; ${JSON.stringify(job)}`
    console.error(message, err)
    sendTextResponse = {error: {message: err.message, stack: err.stack}, message, success: false}
  }

  await db.processJob({id: job_id, payload: sendTextResponse, state: 'done'})
  .catch(err => {
    const message = `Unable to mark job as processed:done; ${JSON.stringify(job)}`
  })
}

module.exports.processTextMessageJobs = async (jobGroupId=null) => {
  const type = 'text-message'
  const query = db.getUnprocessedJobsFor('text-message')
  if (jobGroupId) query.where({jobGroupId})

  const jobs = await query
    .catch(err => {
      console.error(`Unable to fetch job groups ${JSON.stringify({type, jobGroupId})}`, err)
      return Promise.resolve([])
    })
  // console.log(">>>jobs", jobs.length)

  for (let idx=0; idx<jobs.length; idx++) {
    await processJob(jobs[idx])
  }
}

console.log(">>>process.argv", process.argv)
if (process.env.ONE_OFF === 'true') {
  ;(
  async () => {
    await module.exports.processTextMessageJobs()
    db.destroy()
  }
  )()
  .catch(err => console.error(err))
} else {
  console.log("NOTE: if you are attempting to run the workers manually, please include 'ONE_OFF=true' in the supplied environment variables")
}
