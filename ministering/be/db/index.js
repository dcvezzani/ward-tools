const knex = require('knex')
const config = require('../knexfile.js')

const db = knex(config.local)

module.exports.destroy = () => {
  db.destroy()
}

module.exports.addTextMessagesToQueue = payload => {
  // e.g., [{ message, name, phone }]
  return db('queue').insert(payload)
    .catch(err => console.error(`Unable to add text messages to queue`, err))
}

module.exports.getJobGroupsFor = type => {
  return db('queue').where({type}).orderBy('created_at', 'desc')
}

module.exports.getUnprocessedJobsFor = type => {
  const mostRecentJobGroupId = db('queue').select(['jobGroupId']).where({type}).whereNull('processed_at').groupBy(['jobGroupId', 'created_at']).orderBy([{ column: 'created_at', order: 'desc' }]).limit(1)
  return db('queue').whereIn('jobGroupId', mostRecentJobGroupId).where({type}).whereNull('processed_at').orderBy([{ column: 'id', order: 'desc' }])
  // select * from queue where jobGroupId in (select jobGroupId from queue group by jobGroupId, created_at order by created_at desc limit 1) and processed_at is null order by id desc
}

module.exports.processJob = ({id, payload, state='begin'}) => {
  return db('queue').where({id})
  .update({id, state, processed_payload: JSON.stringify(payload), processed_at: db.fn.now()})
    .catch(err => console.error(`Unable to mark job as processed; JSON.stringify({id, payload, state})`, err))
}

module.exports.clearTextMessagesFromQueue = type => {
  return db('queue').where({type}).del()
    .catch(err => console.error(`Unable to clear text messages from queue`, err))
}

// (async () => {
// const chk = await module.exports.getUnprocessedJobsFor('text-message')
//   console.log(">>>chk", chk)
// db.destroy()
// })()
