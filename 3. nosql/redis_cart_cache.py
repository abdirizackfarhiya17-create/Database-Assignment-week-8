import redis
import json

# Connect to local isolated Redis cache engine
r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

def update_tenant_cart(tenant_id, user_id, product_id, quantity):
    """
    Manages active ephemeral shopping cart sessions.
    High-frequency key-value lookups bypass heavy PostgreSQL disk writes.
    """
    cart_key = f"tenant:{tenant_id}:user:{user_id}:cart"
    
    # Store or update quantities instantly inside an in-memory hash map
    r.hset(cart_key, product_id, quantity)
    # Set an expiration of 2 hours (7200 seconds) to auto-expire abandoned sessions
    r.expire(cart_key, 7200)
    print(f"Successfully cached transient item session for user {user_id} under tenant {tenant_id}.")

def get_active_cart(tenant_id, user_id):
    cart_key = f"tenant:{tenant_id}:user:{user_id}:cart"
    return r.hgetall(cart_key)

# --- ARCHITECTURAL JUSTIFICATION NOTE ---
# Problem: Shopping cart modifications generate high-frequency read/write volumes. 
# Storing these volatile states in PostgreSQL triggers continuous MVCC page updates, 
# resulting in catastrophic disk write amplification and table bloat.
# Solution: Redis stores active session data entirely in RAM as lightweight hashes. 
# This handles sub-millisecond mutations smoothly and leaves our core PostgreSQL 
# relational engine unburdened to focus strictly on finalized checkout processing.
