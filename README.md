
## protobuf-cmake

usage:

```cmake
include(protobuf-cmake/Protobuf.cmake)
```

## Example: add new libraries

```cmake
add_protobuf_library(myAwesomeProtobufLibBase proto_file_base.proto)

add_protobuf_library(myAwesomeProtobufLib proto_file1.proto proto_files.proto)
target_link_protobuf_libraries(myAwesomeProtobufLib PUBLIC myAwesomeProtobufLibBase)
```

## Example: link libraries

```cmake
target_link_protobuf_libraries(myAwesomeProtobufLib PUBLIC myAwesomeProtobufLibBase)
```

Then you can write protobuf spec for `myAwesomeProtobufLib`:

```protobuf
// proto_file1.proto

import "proto_file_base.proto"
```

## Example: include directories

You can add more directories to the target.

```cmake
target_include_protobuf_directories(myAwesomeProtobufLib PUBLIC dir1 dir2 dirMore...)
```

## Example: link/include customized directories/libraries

```cmake
target_include_directories(myAwesomeProtobufLib PUBLIC include)
target_link_libraries(myAwesomeProtobufLib PUBLIC ${ProtoDependencies})
```

## Example: reset protobuf root

```cmake
add_protobuf_library(myAwesomeProtobufLib proto_file_base.proto PROTO_ROOT path/to/proto_root)
```
