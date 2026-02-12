# Create migration

Create a new migration based on user input

## Guidlines
Check for a @lib/database/README.md file in the project root to follow the guidelines therein.

## Steps
1. Ask the user what sort of migration they're doing to get a sense of what tables and columns are being impacted. Ask them any meaningful follow up questions. 
2. Call rails generate migration passing the appropriate arguments based on step 1
3. Update the resulting migration file as necessary to fit the needs and follow best practices from the migrations docs

