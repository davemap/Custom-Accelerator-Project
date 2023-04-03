# Accelerator System Top-Level

This repo is the top-level repository which contains accelerator and SoC Labs provided design IP in forms of git subrepositories.

The SoC wiring is handled in this repository too, along with design and verification for accelerator wrappers.

## Creating own top-level

The first stage of putting your accelerator into a SoC is to build the accelerator in your own repository. 

Once you have a custom design repository, you are able to fork the template System Top-level repository and make some changes.

After forking, you need to add your own repository as a submodule. The first thing to do is to clone your new forked top-level.

## Cloning 

To clone this repository and its subrepository, use the following command:

`git clone --recusrive $REPO_NAME`

Once the repository and the subrepository has been cloned, the next stage is to initalise the environment variables and check out the sub repositories to a branch.

First navigate to the top of this cloned repository and run:

`source set_env.sh` 

This sets the environment variables related to this project and creates visability to the scripts in the flow directory. Because of this, you scan now run:

`soc-init`

This checks out all the repositories to the `main` branch. You are then able to check out the sub repos to the desired branches.

## Adding Submodule

After setting up your workarea, you now need to add your accelerator design repository as a subrepo.

From `$DESIGN_ROOT`, you are able to run:

`git submodule status` 

This lists the sub repositories and their branches. Make sure these are all you are expecting other than your design repo and you can then use the 

`git submodule add -b $BRANCH $REPOSITORY_URL`

to add the repo into this work area.

You then need to push the .gitmodules file back to remote to save this configuration.