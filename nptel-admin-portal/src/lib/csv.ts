export function convertToCSV(data: Array<Record<string, any>>): string {
  if (data.length === 0) return ''
  
  const headers = Object.keys(data[0])
  const csvHeaders = headers.map(h => `"${h}"`).join(',')
  
  const csvRows = data.map(row => {
    return headers.map(header => {
      const value = row[header]
      if (value === null || value === undefined) return ''
      if (typeof value === 'string' && value.includes(',')) {
        return `"${value.replace(/"/g, '""')}"`
      }
      return `"${value}"`
    }).join(',')
  })
  
  return [csvHeaders, ...csvRows].join('\n')
}

export function downloadCSV(data: Array<Record<string, any>>, filename: string) {
  const csv = convertToCSV(data)
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', filename)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
