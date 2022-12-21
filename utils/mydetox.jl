#!/usr/bin/env julia

using ArgParse

args_settings = ArgParseSettings()
@add_arg_table args_settings begin
    "-n", "--just-print", "--dry-run"
        help = "Do everything but the actual renaming, instead just print the name of each file that would be renamed."
        action = :store_true
        dest_name = "dry_run"
end
args = parse_args(ARGS, args_settings, as_symbols=true)

RegexEscaped(str) = Regex(replace(str, r"([.+*(){}])" => s"\\\1"))

ismatch(pattern::Regex, str) = match(pattern, str) !== nothing
ismatch(pattern::String, str) = pattern == str

function isexcluded(path, file)
    exclude_file = [
        "node_modules"
        ".venv/"
        ".nox/"
        ".git/"
    ]
    exclude_path = [
        # exclude top-level . folders
        RegexEscaped(homedir()) * r"/\..*/"
    ]
    return any(exclude_file) do pattern
        ismatch(pattern, file)
    end || any(exclude_path) do pattern
        ismatch(pattern, path)
    end
end

function rename(filename)
    replace(
        filename,
        r"""[\:*?"]""" => "-",
        r"[|<>]" => "_",
        # remove trailing . and spaces for both file and dir names
        r"(\s|[.])+(/?)$" => s"\2",
    )
end

function main(; dry_run=false)
    # we make all directories end on "/"
    dirs = [homedir() * "/"]

    while !isempty(dirs)
        current_dir = popfirst!(dirs)
        for file in readdir(current_dir)
            path = "$current_dir$file"

            islink(path) && continue

            path_isdir = isdir(path)
            if path_isdir
                file *= "/"
                path *= "/"
            end

            isexcluded(path, file) && continue
            file_renamed = rename(file)
            path_renamed = "$current_dir$file_renamed"
            if file != file_renamed
                print("""mv "$path" "$path_renamed" """)
                if !dry_run
                    mv(path, path_renamed)
                end
            end
            path_continue = dry_run ? path : path_renamed
            if isdir(path_continue)
                push!(dirs, path_continue)
            end
        end
    end
end

main(; args...)