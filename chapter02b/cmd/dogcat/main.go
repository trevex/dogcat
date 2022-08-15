package main

import (
	"context"
	"flag"
	"os"
	"os/signal"
	"syscall"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"

	"github.com/NucleusEngineering/dogcat/chapter02b/server"
)

func main() {
	log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	rootCmd := &cobra.Command{
		Use:           "dogcat action [flags]",
		SilenceErrors: true,
	}
	flags := rootCmd.PersistentFlags()
	flags.AddGoFlagSet(flag.CommandLine)

	// Add all sub-commands
	rootCmd.AddCommand(server.NewServerCmd())

	// Make sure to cancel the context if a signal was received
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-sigs
		log.Warn().Str("signal", sig.String()).Msg("received signal")
		cancel()
	}()

	if err := rootCmd.ExecuteContext(ctx); err != nil {
		log.Error().Err(err).Msg("command failed")
		os.Exit(1)
	}
}
