package output

import (
	"fmt"
	"io"
	"text/tabwriter"
)

func EcosystemTable(w io.Writer, rows [][4]string) {
	tw := tabwriter.NewWriter(w, 0, 8, 2, ' ', 0)
	fmt.Fprintln(tw, "NAME\tSTATUS\tURL\tKUBECONFIG")
	for _, row := range rows {
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\n", row[0], row[1], row[2], row[3])
	}
	_ = tw.Flush()
}
