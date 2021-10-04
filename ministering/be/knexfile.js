// Update with your config settings.

module.exports = {

  local: {
    client: 'sqlite3',
    connection: {
      filename: './data/queue.sqlite3'
    },
    migrations: {
      tableName: 'knex_migrations',
      directory: './data/migrations',
    },
    useNullAsDefault: true,
  },

};
