define avstapp::download_tar_file(
    $work_dir = '/tmp',
    $file_path = undef,
){
    if ($file_path) {
        $real_file_path = $file_path
    }else {
        $tarball_url_splitted = split($name, '/')
        $tarball_file_name = $tarball_url_splitted[-1]
        $real_file_path = "${work_dir}/${tarball_file_name}"
    }

    exec { $name :
        cwd     => $work_dir,
        command => "wget ${name}",
        unless  => ["test -f ${real_file_path}"],
        timeout => 3600,
    }
}
