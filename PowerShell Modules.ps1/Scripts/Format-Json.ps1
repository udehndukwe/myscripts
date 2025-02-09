function Format-Json {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string]$jsonData
    )
    # Deserialize JSON
    $data = $jsonData | ConvertFrom-Json

    # Extract Schema and Values
    $schema = $data.Schema
    $values = $data.Values

    # Map the schema columns to the values and create objects
    $parsedData = foreach ($valueRow in $values) {
        $obj = [PSCustomObject]@{}
        for ($i = 0; $i -lt $schema.Count; $i++) {
            $columnName = $schema[$i].Column
            $obj | Add-Member -MemberType NoteProperty -Name $columnName -Value $valueRow[$i]
        }
        $obj
    }

    $parsedData | Format-Table -AutoSize

}