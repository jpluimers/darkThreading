# Dependencies

The darkThreading library depends on four other dark libraries:

  * darkUnicode      https://github.com/chapmanworld/darkUnicode
  * darkCollections  https://github.com/chapmanworld/darkCollections
  * darkIO           https://github.com/chapmanworld/darkIO
  * darkLog          https://github.com/chapmanworld/darkLog
  
These dependencies are used by other projects, including the darkGlass engine project of which the darkThreading library is a part. 
Due to limitations in nested submodule support within git, these dependencies have not been added to the project, and must therefore be cloned separately.
Each project has paths configured with the assumption that all dark libraries are cloned into the same parent directory, as follows...

\darkLibs\darkUnicode
\darkLibs\darkCollections
\darkLibs\darkIO
\darkLibs\darkLog
\darkLibs\darkThreading

You may rename the 'darkLibs' directory as you wish, so long as each of the sub-directories remain under the same parent directory.
Once you have cloned each of these libraries, open the pkgDarkThreading in the RAD Studio IDE and build it.

# Using darkThreading

In order to use darkThreading within your own project, you must add the output directory for each of the dark libraries to your path.
Within the IDE, from within "Project Options" ensure that the "Target" drop-down is set to "All configurations - All Platforms"
Now add to your search path as follows:

  * .....\darkUnicode\out\$(Platform)\$(Config)
  * .....\darkCollections\out\$(Platform)\$(Config)
  * .....\darkIO\out\$(Platform)\$(Config)
  * .....\darkLog\out\$(Platform)\$(Config)
  * .....\darkThreading\out\$(Platform)\$(Config)
  
(where ..... is the directory in which you cloned the dark library projects).
