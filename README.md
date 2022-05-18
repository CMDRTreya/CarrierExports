# CarrierExports
Lists all active trade export orders for owned Fleet Carriers in the game "Elite Dangerous"

## Installation
Extract to a folder of your choice and run either directly or via the included AHK interpreter .exe

## Description
FC market exports, in their current form, exhibit the following behaviour:
- Once set up they will remain active indefinitely even after the commodity's stock has been fully sold
- As long as the stock remains at zero the export order will be invisible in the UI

The purpose of this script is to provide this missing information by extracting the relevant entries from the game's log files.

### Removing invisible export orders
If a unwanted trade order is hidden as described above it is not possible to remove it directly. One workaround to this is to first place an import order for the commodity in question which as a side effect will remove the export.
