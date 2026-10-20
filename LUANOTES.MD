# Lua Notes

## Tables

**Lua's only data structure.** Arrays, dictionaries, objects, modules (even `love` itself) are all tables.

- A table is an **associative array**: it maps **keys** to **values**.
- A key can be any value **except `nil`**.
- An ordinary array is just the special case where the keys are `1..n` (Lua calls this a **sequence**).
- `{}` is the table **constructor**: it creates a new, empty table.

```lua
local lines  = { "FPS: 60", "Ball: 412, 87" }   -- used as a list: keys 1, 2
local paddle = { x = 20, y = 300 }              -- used as a dictionary: keys "x", "y"
```

### `nil` rules

`nil` means **absence**. That single idea explains every rule:

| Action | Result | Why |
|---|---|---|
| `t[k] = nil` | **removes** the entry | "holds nothing" and "isn't there" are the same state |
| `t.missing` | returns `nil` | nothing stored under that key |
| `t[nil]` (read) | returns `nil` | asking for "no label" finds nothing; harmless |
| `t[nil] = 5` (write) | **error**: `table index is nil` | you can't file something under "no label" |

Common bug: a key variable that was never set (typo or missing value) is `nil`, so writing with it errors.

---

## Table internals (Lua 5.1)

### The hybrid design

Every table has **two parts at the same time**. Either can be empty (size 0).

| Part | Holds | Access |
|---|---|---|
| **Array part** (`TValue *array`) | integer keys `1..n` | direct index, **no hashing** |
| **Hash part** (`Node *node`) | every other key (strings, booleans, sparse integers like `t[1000]`) | hash the key, go to its bucket |

Lua chooses which part a key lives in automatically. When a table grows and **rehashes**, it picks an array size `n` so that more than half of slots `1..n` are in use.

```
 local t = { "a", "b", "c", fps = 60, name = "p1" }

 ARRAY PART               HASH PART
 [1] "a"                  bucket 0: "name" = "p1"
 [2] "b"                  bucket 1: "fps"  = 60
 [3] "c"
```

### Lookup flow

```
 integer key in 1..n:   key ──► array[key] ──► value

 any other key:         key ──► hash ──► main position (bucket)
                                      ──► walk collision chain, compare keys
                                      ──► value (or nil if not found)
```

- `mainposition()` picks a hash function based on the key's **type**, then returns the key's **main position**: a pointer to the bucket (`Node`) where the key *should* live.
- `luaH_get()` starts at that slot, follows the collision chain comparing keys, and returns the value when it finds a match.

### The structs (`lobject.h`)

**`Table`**: the two parts are literally two fields.

```c
typedef struct Table {
  CommonHeader;
  lu_byte flags;           /* 1<<p means tagmethod(p) is not present */
  lu_byte lsizenode;       /* log2 of size of `node' array */
  struct Table *metatable;
  TValue *array;           /* array part */
  Node *node;              /* hash part: pointer to the first bucket */
  Node *lastfree;          /* any free position is before this position */
  GCObject *gclist;
  int sizearray;           /* size of `array' array */
} Table;
```

| Field | Meaning |
|---|---|
| `array`, `sizearray` | the array part and its size |
| `node` | pointer to the **first bucket**; the hash part is the contiguous block of `Node`s starting here (same pattern as `float *coords = new float[n]`) |
| `lsizenode` | hash part size as a power of 2 (`3` means 8 buckets), so "hash mod size" becomes a fast bit mask |
| `lastfree` | used to find a free slot for colliding keys |
| `metatable` | where `__index` and other metamethods live (how objects and classes work) |

**`Node`**: one bucket.

```c
typedef struct Node {
  TValue i_val;            /* the value */
  TKey i_key;              /* the key, plus `next' for chaining */
} Node;
```

**`TKey`**: the key, with a link to the next node in its collision chain.

```c
typedef union TKey {
  struct {
    TValuefields;
    struct Node *next;     /* for chaining */
  } nk;
  TValue tvk;
} TKey;
```

**Collisions (chained scatter with Brent's variation):** when two keys hash to the same bucket, the extra key goes into a **free slot inside the same `node` block** (found via `lastfree`) and is linked with `next`. Chains live inside one array: fewer allocations, better memory locality, good performance even at a 100% load factor.

### `mainposition()` (`ltable.c`)

Returns the `main' position of an element: the bucket its hash value points to.

```c
static Node *mainposition (const Table *t, const TValue *key) {
  switch (ttype(key)) {
    case LUA_TNUMBER:
      return hashnum(t, nvalue(key));
    case LUA_TSTRING:
      return hashstr(t, rawtsvalue(key));       /* uses the string's stored hash */
    case LUA_TBOOLEAN:
      return hashboolean(t, bvalue(key));
    case LUA_TLIGHTUSERDATA:
      return hashpointer(t, pvalue(key));
    default:
      return hashpointer(t, gcvalue(key));      /* tables, functions: hash the address */
  }
}
```

- **Strings:** the hash is computed once when the string is created (interned) and stored in it (`tsv.hash`), so field lookups like `paddle.y` don't rehash `"y"` every time.
- **Default case:** tables and functions are hashed by **memory address**, which is why two identical-looking tables are different keys.

### `ltable.h`: the public API

`luaH_` prefix = **H**ash; C has no namespaces, so the prefix acts as one.

| Function | Lua operation |
|---|---|
| `luaH_getnum` / `luaH_setnum` | `t[5]` (array fast path) |
| `luaH_getstr` / `luaH_setstr` | `t.name` |
| `luaH_get` / `luaH_set` | `t[anything]` |
| `luaH_new(narray, lnhash)` | `{}` (sizes both parts) |
| `luaH_next` | `pairs()` |
| `luaH_getn` | `#t` |

`mainposition` is `static` (private to `ltable.c`) and only exposed in debug builds: an internal detail, not part of the contract.

### Note: `ltable.c` vs `ltablib.c`

| File | What it is |
|---|---|
| `ltable.c` | the table **data structure** inside the interpreter |
| `ltablib.c` | the `table` **library** you call from Lua: `table.concat`, `table.insert`, `table.sort` |

### Note: LuaJIT

LÖVE runs **LuaJIT**, a separate reimplementation of Lua 5.1. The language rules above apply exactly; the internal C code differs, though it uses the same array part plus hash part idea.

---

## Sources

- [Lua 5.1 Reference Manual, §2.2 Values and Types](https://www.lua.org/manual/5.1/manual.html#2.2)
- [The Implementation of Lua 5.0, §4 Tables (PDF)](https://www.lua.org/doc/jucs05.pdf)
- [ltable.c (Lua 5.1)](https://www.lua.org/source/5.1/ltable.c.html)
- [ltable.h (Lua 5.1)](https://www.lua.org/source/5.1/ltable.h.html)
- [lobject.h (Lua 5.1)](https://www.lua.org/source/5.1/lobject.h.html)

