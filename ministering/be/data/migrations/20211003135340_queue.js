
exports.up = async knex => {
  await knex.schema.createTable('queue', (table) => {
    table.increments('id')
    table.string('type')
    table.string('jobGroupId')
    table.string('state')
    table.text('payload')
    table.timestamp('created_at').defaultTo(knex.fn.now())
    table.timestamp('updated_at').defaultTo(knex.fn.now())
    table.timestamp('processed_at')
    table.timestamp('processed_payload')
  })
};

exports.down = async knex => {
  await knex.schema.dropTable('queue')
};
