@Composable
fun WeatherCenterScreen(
    state: WeatherState,
    onRunReport: () -> Unit,
    onFiltersChange: (Filters) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().background(Color(0xFF0E0F12))) {
        TopAppBar(title = { Text("Weather Center") }, actions = {
            TextButton(onClick = { /* export */ }) { Text("Export CSV") }
            Button(onClick = onRunReport) { Text("Run Report") }
        })
        FiltersBar(
            filters = state.filters,
            onChange = onFiltersChange,
            modifier = Modifier
                .background(Color(0xFF0E0F12))
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
        )
        LazyColumn(
            modifier = Modifier.weight(1f),
            contentPadding = PaddingValues(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(state.results) { row ->
                val border = when (row.severity) {
                    1 -> Color(0xFF16A34A)
                    2 -> Color(0xFFF59E0B)
                    3 -> Color(0xFFF97316)
                    4 -> Color(0xFFEF4444)
                    else -> Color(0xFFB91C1C)
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, Color(0xFF2A2D35), RoundedCornerShape(12.dp))
                        .drawBehind {
                            drawRect(border, size = Size(6.dp.toPx(), size.height))
                        }
                        .background(Color(0xFF17181C), RoundedCornerShape(12.dp))
                        .padding(12.dp)
                ) {
                    Column(Modifier.weight(1f)) {
                        Text(row.name, fontWeight = FontWeight.SemiBold)
                        Text("Gust: ${row.gust} mph · Sustained: ${row.sustained} mph",
                            color = Color(0xFFA2A7B5), fontSize = 12.sp)
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text("Sev ${row.severity}", fontWeight = FontWeight.Bold, color = border)
                        row.crewRec?.let { Text("$it crews") }
                    }
                }
            }
        }
    }
}