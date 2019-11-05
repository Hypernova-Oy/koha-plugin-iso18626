const gulp = require('gulp');
const release = require('gulp-github-release');
const fs = require('fs');
const run = require('gulp-run');
const dateTime = require('node-datetime');

const dt = dateTime.create();
const today = dt.format('Y-m-d');

const package_json = JSON.parse(fs.readFileSync('./package.json'));
const release_filename = `${package_json.name}-v${package_json.version}.kpz`;

const pm_name = 'SelfService';
const pm_file = pm_name+'.pm';
const pm_file_path = path.join('Koha', 'Plugin', 'Fi', 'KohaSuomi');
const pm_file_path_full = path.join(pm_file_path, pm_file);
const pm_file_path_dist = path.join('dist', pm_file_path);
const pm_file_path_full_dist = path.join(pm_file_path_dist, pm_file);
const pm_bundle_path = path.join(pm_file_path, pm_name);

console.log(release_filename);
console.log(pm_file_path_full_dist);

gulp.task('build', () => {
    run(`
        mkdir dist ;
        cp -r Koha dist/. ;
        sed -i -e "s/{VERSION}/${package_json.version}/g" ${pm_file_path_full_dist} ;
        sed -i -e "s/1900-01-01/${today}/g" ${pm_file_path_full_dist} ;
        cd dist ;
        zip -r ../${release_filename} ./Koha ;
        cd .. ;
        rm -rf dist ;
    `).exec();

});

gulp.task('release', () => {
    gulp.src(release_filename)
        .pipe(release({
            manifest: require('./package.json') // package.json from which default values will be extracted if they're missing
        }));
});
