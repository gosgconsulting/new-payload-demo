import payload from 'payload'
import pg from 'pg'
import path from 'path'
import { fileURLToPath } from 'url'

const { Pool } = pg

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const DATABASE_URL = process.env.DATABASE_URI
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
      console.log('✅ Tables already exist. Skipping Payload init.')
    } else {
      console.log('⏳ No tables found. Running Payload init...')
      await payload.init({
        secret: PAYLOAD_SECRET,
        local: true,
        config: path.resolve(__dirname, 'src', 'payload.config.js'),
      })
      console.log('✅ Payload initialized, tables should now be created.')
    }

    await pool.end()
  } catch (err) {
    console.error('❌ Error initializing DB:', err)
    process.exit(1)
  }
}

run()
