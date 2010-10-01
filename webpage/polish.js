function versionGreaterOrEqual(version1, version2)
{
    var versionLength = Math.min(version1.length, version2.length);
    for (var i = 0; i < versionLength; ++i)
    {
        var v1 = parseInt(version1[i]);
        var v2 = parseInt(version2[i]);

        if (v1 > v2)
            return true;
        if (v1 < v2)
            return false;
    }

    if (version1.length < version2.length)
        return false;

    return true;
}

function getQueryVariable(variable)
{
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split("=");
        if (pair[0] == variable)
        {
            return pair[1];
        }
    }
    return null;
}

function hideOlder()
{
    var sourceVersion = getQueryVariable('currentversion');
    if (!sourceVersion)
        return;
    sourceVersion = sourceVersion.split('.');

    var hideFollowing = false;
    var versions = document.getElementsByClassName('version');
    for (var i = 0; i < versions.length; ++i)
    {
        var version = versions[i];
        if (hideFollowing)
        {
            version.style.display = 'none';
        }
        else
        {
            if (versionGreaterOrEqual(sourceVersion, version.id.split('.')))
            {
                version.style.display = 'none';
                hideFollowing = true;
            }
        }
    }
}

window.onload = hideOlder;
