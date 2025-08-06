import { migrate } from 'payload/database'
import payload from 'payload'
import pg from 'pg'

const { Pool } = pg

const DATABASE_URL = process.env.DATABASE_URL
const PAYLOAD_SECRET = process.env.PAYLOAD_SECRET

const pool = new Pool({
  connectionString: DATABASE_URL,
})

async function hasTables() {
  const res = await pool.query(`
    SELECT COUNT(*) FROM information_schema.tables 
    WHERE table_schema = 'public';
  `)
  const count = parseInt(res.rows[0].count, 10)
  return count > 0
}

const run = async () => {
  try {
    const tablesExist = await hasTables()

    if (tablesExist) {
      console.log('✅ Tables already exist. Skipping migration.')
    } else {
      console.log('⏳ No tables found. Running Payload migration...')
      await payload.init({
        secret: PAYLOAD_SECRET,
        local: true,
      })
      await migrate()
      console.log('✅ Migration completed.')
    }

    await pool.end()
  } catch (err) {
    console.error('❌ Error initializing DB:', err)
    process.exit(1)
  }
}

run()
