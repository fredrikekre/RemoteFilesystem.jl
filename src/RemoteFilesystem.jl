module RemoteFilesystem

"""
    RemoteFS(host, path=""; ro::Bool=false)

Mount a remote filesystem located at `host:path` to the local filesystem.

## Examples
```julia
# Mount remote user home directory
RemoteFs("fredrik@remotehost")

# Mount remote directory /home/fredrik/files in read-only mode:
RemoteFS("fredrik@remotehost", "/home/fredrik/files"; ro=true)
"""
mutable struct RemoteFS
    host::String
    remotepath::String
    localpath::String
    function RemoteFS(host, path=""; ro::Bool=false)
        sshfs = Sys.which("sshfs")
        sshfs === nothing && error("sshfs not found")
        fusermount = Sys.which("fusermount")
        fusermount === nothing && error("fusermount not found")
        localpath = mktempdir(; cleanup=false)
        cmd = `$sshfs $host:$path $localpath`
        ro && (cmd = `$cmd -o ro`)
        run(cmd)
        rfs = new(host, path, localpath)
        function unmount_fs(rfs::RemoteFS)
            run(`$fusermount -u $(rfs.localpath)`)
            rm(rfs.localpath; recursive=true, force=true)
        end
        finalizer(unmount_fs, rfs)
        return rfs
    end
end

Base.joinpath(rfs::RemoteFS, path::String, paths::String...) = joinpath(rfs.localpath, path, paths...)
Base.readdir(rfs::RemoteFS) = readdir(rfs.localpath)

end # module
