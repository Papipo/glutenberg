import glutenberg/client
import glutenberg/database
import lustre

pub fn main() {
  lustre.start(client.app(), "#app", database.init())
}
