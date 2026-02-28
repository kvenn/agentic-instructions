* If using SQL
	- Use postgres
	- Leverage CTEs to break up large queries
* Always keep the data layer in their own files. It should be easy to swap out the data store
* Never make fully unbounded queries - keep performance in mind