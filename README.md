# ulid-gm

An implementation of [ULID](https://github.com/ulid/spec) in GameMaker.

Originally written for [Void Stranger Endless Void](https://github.com/skirlez/void-stranger-endless-void), I've polished it up, made it correct (as far as I can tell)

## Usage

### `generate_ulid([buffer])`
Generates and returns a ULID string.
Optionally accepts a `buffer` to create the ULID from. If a buffer is passed in, it will not be freed.

### `generate_ulid_buffer()`
Returns a ULID as a buffer of fixed length.

### Small Quirk
If `global.ulid_gm_throw_on_random_overflow` is set, functions will throw an error if the random component overflows
which can happen if an extremely large (around 2^79 on average) amount of ULIDs are generated in the same millisecond.

**Note that it is set to true by default**. Though probabilistically speaking no one will ever encounter this issue.

## License
The code is licensed under the terms of the MIT license, found in this repository.

## Contributing
Please contribute
